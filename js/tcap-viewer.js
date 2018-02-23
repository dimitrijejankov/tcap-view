var myPlan;
var error;

var showGraphForTCAP = function(tcap) {

    if (tcapParser.parse(tcap)) {
        var id = 1;

        var openNodes = myPlan.scans;
        var nodeData = [];

        var nodeNameIDs = {};
        var IDtoNode = {};

        // generate the nodes
        while (openNodes.length !== 0) {

            // get the next node id
            var curNodeId = id++;

            // get the current node
            var node = openNodes[0];

            if(!(node.output.setName in nodeNameIDs)) {
                // add a new node
                nodeData = nodeData.concat([{"id": curNodeId, "label": node.output.setName}]);

                // add the id for the node
                IDtoNode[curNodeId] = node;

                // set the id for the node name
                nodeNameIDs[node.output.setName] = curNodeId;

                // grab the consumers
                var consumers = myPlan.consumers[node.output.setName];

                // check if we have them
                if(consumers !== undefined) {

                    // add them to the open nodes
                    openNodes = openNodes.concat(consumers);
                }
            }

            // remove the first element
            openNodes = openNodes.splice(1);
        }


        openNodes = myPlan.scans;

        var edgeData = [];
        var visitedNodes = {};

        // generate the edges
        while (openNodes.length !== 0) {

            // get the current node
            node = openNodes[0];

            // if we already have visited this node skip it
            if(node.output.setName in visitedNodes) {

                // remove the first element
                openNodes = openNodes.splice(1);

                // go to the next one
                continue;
            }

            // grab the consumers
            consumers = myPlan.consumers[node.output.setName];

            // check if we have them
            if(consumers !== undefined) {

                // go through each consumers
                for(var i = 0; i < consumers.length; ++i) {
                    edgeData = edgeData.concat([{from: nodeNameIDs[node.output.setName], to: nodeNameIDs[consumers[i].output.setName], "arrows": "to"}]);
                }

                // add them to the open nodes
                openNodes = openNodes.concat(consumers);
            }

            // add the nodes to the visited nodes
            visitedNodes[node.output.setName] = true;

            // remove the first element
            openNodes = openNodes.splice(1);
        }

        // create an array with nodes
        var nodes = new vis.DataSet(nodeData);

        // create an array with edges
        var edges = new vis.DataSet(edgeData);

        // create a network
        var container = document.getElementById('mynetwork');

        // provide the data in the vis format
        var data = {
            nodes: nodes,
            edges: edges
        };

        var options = {
            layout: {
                hierarchical: {
                    sortMethod: "directed",
                    nodeSpacing : 400
                }
            },
            physics: {
                enabled: false
            },
            edges: {
                smooth: true,
                arrows: {to : true }
            }
        };

        var network = new vis.Network(container, data, options);

        network.on("click", function (params) {
            $('#info-table').empty().append($.json2table(IDtoNode[this.getNodeAt(params.pointer.DOM)], "TCAP Node Info"));
        });
    }
};