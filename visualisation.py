from py2neo import  Graph, Path, Node, Relationship

graph = Graph("bolt://localhost:7687", auth=("neo4j", "bram123"))

tx = graph.begin()
nodes = []
for name in ["Alice", "Bob", "Carol"]:
    a = Node("Person", name=name)
    nodes.append(a)
    tx.create(a)


friends = Relationship(nodes[0], "KNOWS", nodes[1])
friends_twee = Relationship(nodes[1], "KNOWS", nodes[0])

tx.create(friends)
tx.create(friends_twee)
tx.commit()
