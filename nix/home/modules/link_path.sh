# Create or repair a symlink without overwriting unmanaged user data.
shrc_link_path() {
  if [ "$#" -ne 2 ]; then
    echo "shrc_link_path requires exactly two arguments: SOURCE TARGET" >&2
    return 2
  fi

  source_path="$1"
  target_path="$2"

  case "$source_path" in
  /*) ;;
  *)
    echo "shrc_link_path SOURCE must be an absolute path: $source_path" >&2
    return 2
    ;;
  esac

  case "$target_path" in
  /*) ;;
  *)
    echo "shrc_link_path TARGET must be an absolute path: $target_path" >&2
    return 2
    ;;
  esac

  # Fail early when the repository-managed source is missing. This catches
  # typos and incomplete checkouts before touching anything in $HOME.
  run test -e "$source_path"

  # The target's parent may not exist yet, especially for nested agent paths.
  run mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ]; then
    # A symlink is safe for us to manage. Repair stale links, including
    # dangling links (which are still detected by -L), but leave correct links
    # untouched so activation remains idempotent.
    if [ "$(readlink -f "$target_path")" != "$(readlink -f "$source_path")" ]; then
      run rm "$target_path"
      run ln -s "$source_path" "$target_path"
    fi
  elif [ -e "$target_path" ]; then
    # Existing regular files and directories may contain user data. Refuse to
    # replace them rather than silently deleting or hiding that data.
    echo "Refusing to replace existing path $target_path; review it against $source_path before activating" >&2
    return 1
  else
    # No target exists, so create the intended link.
    run ln -s "$source_path" "$target_path"
  fi
}
