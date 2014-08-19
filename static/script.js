
var scale, total_time;
var chart = $('#chart');

function setup(root){
  scale = d3.scale.linear()
    .domain([root.start, root.finish])
    .range([0, 100]);
  total_time = (root.finish - root.start);

  var elm = nodeAndChildren(root, 0, total_time);
  chart.empty();
  chart.append(elm);
}

$('#button').click(function(){
  setup(JSON.parse($('#trace').val()));
});

//recursively draw stack/time trace
function nodeAndChildren(node, depth, total_time){
  //create a div for the node and its children.
  //create a rectangle for this node.
  //for each child:
  //  get the node for it
  //  set the child's node transform to the appropriate offsets

  var wrapper = $('<div class="wrapper">');
  var entry = $('<div class="entry">'+node.tag+'</div>');
    entry.attr({'tag': node.tag});
    entry.click(function(){
      var obj = _.omit(node, 'children');
      var text = JSON.stringify(obj, undefined, 2);
      console.log(text);
      $('#info').text(text);
    });
  wrapper.append(entry);

  var prevRight = 0;
  for(var i = 0; i < node.children.length; i = i + 1){
    var child = node.children[i];
    var child_node = nodeAndChildren(child, depth+1, total_time);
    var width =  100 * (child.finish - child.start) / total_time;
    child_node.css({
      marginLeft: (scale(child.start) - prevRight) + "%",
      width:width+"%"
    });
    prevRight = scale(child.finish);
    wrapper.append(child_node);
  }
  return wrapper;
}
