# bfs

from email import header


visited = []
queue = []

queue.append(head)
visited.append(head)

while queue:
    node = queue.pop()

        for neighbour in node:
            if neighbour not in visited:
                queue.append(neighbour)
                visited.append(neighbour)

#dfs

visited = []
stack = []

visited.append(head)
stack.append(head)

while stack:
    node = stack.pop()
    if node in path:
        continue
    path.append(node)
    for neighbour in node:
        if neighbout not in visited:
            vistied.append(neighbour)
            stack.append(neighbour)
