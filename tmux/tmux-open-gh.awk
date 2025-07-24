#!/usr/bin/awk -f

# An executable awk script to open the GitHub page for a git repository.
# It expects the path to be passed as a named variable 'repo_path'.
# Example: awk -v repo_path="/path/to/repo" -f this_script.awk

BEGIN {
    # Check if the required variable was passed.
    if (repo_path == "") {
        system("tmux display-message 'Error: repo_path variable not provided.'")
        exit 1
    }

    # Define the shell commands we need to run.
    git_check_cmd = "git -C \"" repo_path "\" rev-parse --is-inside-work-tree"
    git_url_cmd = "git -C \"" repo_path "\" config --get remote.origin.url"

    # First, check if the path is actually a git repo.
    if (system(git_check_cmd " >/dev/null 2>&1") != 0) {
        system("tmux display-message 'Not a git repository.'")
        exit
    }

    # Next, execute the git config command and read its output.
    if ((git_url_cmd | getline remote_url) > 0) {
        # If we got a URL, parse it to get the 'user/repo' part.
        # The '/' inside the character class is escaped for portability.
        sub(/.*github.com[:\/]/, "", remote_url)
        sub(/\.git$/, "", remote_url)

        if (remote_url != "") {
            # Construct the final URL and open it.
            system("open \"https://github.com/" remote_url "\"")
        } else {
            system("tmux display-message 'Could not parse GitHub URL.'")
        }
    } else {
        system("tmux display-message 'No remote origin found.'")
    }

    # It's good practice to close the command pipe.
    close(git_url_cmd)
}