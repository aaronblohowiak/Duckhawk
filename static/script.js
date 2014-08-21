
$('header div').click(function (event) {
  $('section.active, header div.active')
    .removeClass('active');

  $('#' + $(event.target).attr('for'))
    .add(event.target)
    .addClass('active');
});

var scale, zoom, total_time;
var chart = $('#chart'), d3chart = d3.select("#chart");

function setup(root){
  scale = d3.scale.linear()
    .domain([root.start, root.finish])
    .range([0, 100]);

  zoom = d3.behavior.zoom()
      .scaleExtent([1, 10])
      .on("zoom", zoomed);

  zoom(d3chart);

  total_time = (root.finish - root.start);

  var elm = nodeAndChildren(root, 0, total_time);
  chart.empty();
  chart.append(elm);
}

var raw = localStorage.getItem('raw');

if (raw) {
  $('#data textarea').val(raw);
  setup(JSON.parse(raw));
}

$('#data button').click(function(){
  var raw = $('#data textarea').val();
  localStorage.setItem('raw', raw)
  setup(JSON.parse(raw));
});

var chartwrapper = $('#chart > .wrapper').css('transform-origin','0 0')

function zoomed() {
  var translate = d3.event.translate;
  chartwrapper
    .css('font-size', (5 + 5 / d3.event.scale | 0) + 'px')
    .css("transform", "translate(" + translate[0] + 'px, ' + translate[1] + "px) scale(" + d3.event.scale + ")");
}

function nodeAndChildren(node, depth, total_time) {
  var wrapper = $('<div class="wrapper">');
  var entry = $('<div class="entry">'+node.tag+'</div>');
    entry.attr({'tag': node.tag});
    entry.attr({'title': node.tag + ' ' + (node.finish - node.start) + 's'});
    entry.click(function(){
      var obj = _.omit(node, 'children');
      var text = JSON.stringify(obj, undefined, 2);
      console.log(text);
      $('#info').text(text);
    });
  wrapper.append(entry);

  var parent_time = node.finish - node.start;

  var scale = d3.scale.linear()
    .domain([node.start, node.finish])
    .range([0, 100]);

  var prevRight = 0;
  for(var i = 0; i < node.children.length; i = i + 1){
    var child = node.children[i];
    var child_node = nodeAndChildren(child, depth+1, parent_time);
    var width =  100 * (child.finish - child.start) / parent_time;
    child_node.css({
      marginLeft: (scale(child.start) - prevRight) + "%",
      width:width+"%"
    });
    prevRight = scale(child.finish);
    wrapper.append(child_node);
  }
  return wrapper;
}

$('body').on('click', '.entry', function (event) {
  $('.entry.selected').removeClass('selected');
  $(event.target).addClass('selected');
});

$(window).keyup(function (event) {
  if ($('#trace.active')[0]) {
    if (event.which == 37) {
      $('.entry.selected').parent().prev().children().first().click();
    } else if (event.which == 38) {
      $('.entry.selected').parent().parent().children().first().click();
    } else if (event.which == 39) {
      $('.entry.selected').parent().next().children().first().click();
    } else if (event.which == 40) {
      $('.entry.selected').next().children().first().click();
    }
  }
});
