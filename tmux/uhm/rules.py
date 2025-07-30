# List of rules. Each rule is a dictionary.
# The 'action' can be a lambda that returns a tuple: (action_type, command_string)
# The lambda receives two arguments: the matched text and the current pane path.

RULES = [
    {
        "regex": r"[a-f0-9]{40}",
        "color": "highlight_orange",
        # The `cd` command is now explicitly part of the command string.
        # The 'path' argument to the lambda contains the pane's current directory.
        "action": lambda text, path: (
            "exco",
            f"cd '{path}' && echo https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/commit/{text}"
        )
    },
    {
        "regex": r"/Users/ruben/code/[a-zA-Z0-9_./-]+",
        "color": "highlight_cyan",
        # This action doesn't require changing directory, so it's left as is.
        "action": lambda text, path: ("exec", f"open '{text}'")
    },
    {
        "regex": r"([a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)",
        "color": "highlight_blue",
        "action": lambda text, path: ("copy", f"mailto:{text}")
    },
]
