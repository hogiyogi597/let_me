defmodule Expel.Builder do
  @moduledoc false

  def get_acc_attribute(module, name) do
    module
    |> Module.get_attribute(name, [])
    |> Enum.reverse()
  end

  def permit_function(%{} = rules, check_module) do
    rule_clauses = Enum.map(rules, &permit_function_clause(&1, check_module))

    quote do
      @impl Expel.Policy
      def authorized?(action, subject, object \\ nil)

      unquote(rule_clauses)

      def authorized?(action, _, _) when is_atom(action) do
        Logger.warn(
          "Permission checked for rule that does not exist: #{action}",
          action: action,
          policy_module: unquote(check_module)
        )

        false
      end
    end
  end

  defp permit_function_clause(
         {identifier, %Expel.Rule{} = rule},
         check_module
       ) do
    allow_condition = build_conditions(rule.allow, check_module)
    deny_condition = build_conditions(rule.deny, check_module)

    # check for conditions that are always true or false to prevent
    # "this check/guard will always yield the same result" warning
    combined_condition =
      case {allow_condition, deny_condition} do
        {false, _} -> false
        {_, true} -> false
        {_, false} -> allow_condition
        {true, _} -> quote(do: !unquote(deny_condition))
        _ -> quote(do: !unquote(deny_condition) && unquote(allow_condition))
      end

    quote do
      def authorized?(unquote(identifier), subject, object) do
        unquote(combined_condition)
      end
    end
  end

  defp build_conditions([], _), do: false

  defp build_conditions([checks], check_module) do
    build_check(checks, check_module)
  end

  defp build_conditions(conditions, check_module) when is_list(conditions) do
    quote do
      Enum.any?(unquote(Enum.map(conditions, &build_check(&1, check_module))))
    end
  end

  defp build_check([], _), do: false

  defp build_check([check], check_module) do
    build_check(check, check_module)
  end

  defp build_check(checks, check_module) when is_list(checks) do
    quote do
      Enum.all?(unquote(Enum.map(checks, &build_check(&1, check_module))))
    end
  end

  defp build_check(true, _) do
    quote do
      true
    end
  end

  defp build_check(false, _) do
    quote do
      false
    end
  end

  defp build_check(function, check_module) when is_atom(function) do
    quote do
      apply(unquote(check_module), unquote(function), [subject, object])
    end
  end

  defp build_check({function, opts}, check_module)
       when is_atom(function) do
    quote do
      apply(unquote(check_module), unquote(function), [
        subject,
        object,
        unquote(opts)
      ])
    end
  end
end