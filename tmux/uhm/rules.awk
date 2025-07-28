BEGIN {
    _regex_count = 0
    # Rules

    # Git full hash
    _regex_count++
    REGEXES[_regex_count]     = "[a-f0-9]{40}"
    CONTEXTS[_regex_count]    = ""
    RULE_COLORS[_regex_count] = "highlight_orange"
    ACTIONS[_regex_count] = "exco open https://github.com/$(cd PANE_PATH; gh repo view --json nameWithOwner -q .nameWithOwner | /bin/cat)/commit/PLACEHOLDER"

    # Paths on my code folder
    _regex_count++
    REGEXES[_regex_count]     = "/Users/ruben/code/[a-zA-Z0-9_./-]+"
    CONTEXTS[_regex_count]    = ""
    RULE_COLORS[_regex_count] = "highlight_cyan"
    ACTIONS[_regex_count] = "exec open PLACEHOLDER"
}
