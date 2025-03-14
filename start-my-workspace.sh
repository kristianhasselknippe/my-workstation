SESSION_NAME="midio_workspace"

tmux start-server

tmux new-session -d -s $SESSION_NAME

tmux new-window -t $SESSION_NAME -n "nats" "just nats"
tmux new-window -t $SESSION_NAME -n "registry" "just registry"
tmux new-window -t $SESSION_NAME -n "rover" "just rover"
tmux new-window -t $SESSION_NAME -n "editor" "just editor-local-nats"
tmux new-window -t $SESSION_NAME -n "tsc" "just tsc"
tmux new-window -t $SESSION_NAME -n "cursor" "cursor --no-sandbox"

tmux attach-session -t $SESSION_NAME
