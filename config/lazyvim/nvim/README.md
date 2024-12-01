# 💤 Kristians LazyVim config

# Additional configs

## Lazygit

```yaml
git:
  branchLogCmd: "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium --oneline {{branchName}} --"
  merging:
    args: "--no-ff"
  paging:
    externalDiffCommand: difft --color=always --display=inline --syntax-highlight=off
```