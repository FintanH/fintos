{
  description = "Code review of current git changes";
  agent = "reviewer";
  template = ''
    Review the changes shown by `git diff HEAD`.
    Produce a numbered findings list grouped by file.
    Severity levels: info / warning / error.
    End with a one-paragraph overall summary.
  '';
}
