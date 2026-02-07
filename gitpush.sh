#!/bin/bash
chmod +x gitpush.sh
# Prompt for commit message
read -p "Enter commit message: " commit_message

# List all local branches
echo "Select a branch to push to:"
branches=($(git branch --format="%(refname:short)"))
for i in "${!branches[@]}"; do
  echo "$((i+1)). ${branches[$i]}"
done

# Prompt for selection
read -p "Enter branch number: " branch_number

# Validate input
if [[ "$branch_number" -gt 0 && "$branch_number" -le "${#branches[@]}" ]]; then
  branch_name="${branches[$((branch_number-1))]}"
  echo "Pushing to branch: $branch_name"
else
  echo "Invalid selection."
  exit 1
fi

# Run git commands
git add .
git commit -m "$commit_message"
git push -u origin "$branch_name"
