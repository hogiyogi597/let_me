defmodule Expel.Rule do
  @moduledoc """
  A struct for an authorization rule.
  """

  @typedoc """
  Struct for an authorization rule.

  - `action` - The action (verb) to be performed on the object, e.g. `:update`.
  - `allow` - A lists of checks to run to determine whether the action is
    allowed.
  - `deny` - A lists of checks to run to determine whether the action is
    explicitly denied. If any of these checks returns `true`, the end
    result of the permission checks is immediately `false`, even if any of the
    checks in the `allow` field would return `true`.
  - `object` - The object that the action is performed on, e.g. `:article`.
  - `pre_hooks` - Functions to run in order to hydrate the subject and/or object
    before running the allow and deny checks.

  The list entries in the outer list of the `allow` and `deny` fields are
  combined with a logical `OR`. If one of the entries is a list of checks, those
  checks are combined with a logical `AND`.

  Examples:

  - `[{role: :editor}, {role: :writer}]` - role is editor OR role is writer
  - `[[{role: :editor}], [{role: :writer}]]` - same as above
  - `[[{role: :editor}], [{role: :writer}, {:own_resource}]]` -
     (role is editor OR (role is writer AND object is the user's own resource))
  """
  @type t :: %__MODULE__{
          action: atom,
          allow: [check | [check]],
          deny: [check | [check]],
          description: String.t() | nil,
          object: atom,
          pre_hooks: [hook]
        }

  @typedoc """
  A `check` references a function in the configured Checks module.

  Can be either of:

  - A function name as an atom. The function must be a 2-arity function that
    takes the the subject (usually the current user) and the object as
    arguments.
  - A tuple with the function name as an atom and a value in any format. The
    function must be a 3-arity function that takes the subject, the object, and
    the given value as arguments.
  """
  @type check :: atom | {atom, any}

  @typedoc """
  A hook can be registered to hydrate the subject and/or object before passing
  them to the check functions.

  Can be either of:

  - The name of a function defined in the configured Checks module as an atom.
  - A `{module, function}` tuple.
  - A `{module, function, arguments}` tuple.

  In either case, the function must take the subject as the first argument, the
  object as the second argument, and return a tuple with the updated subject and
  object. If an MFA tuple is passed, the given arguments are appended to the
  default arguments.
  """
  @type hook :: atom | {module, atom} | {module, atom, any}

  @enforce_keys [:action, :object]

  defstruct action: nil,
            allow: [],
            deny: [],
            description: nil,
            object: nil,
            pre_hooks: []
end
