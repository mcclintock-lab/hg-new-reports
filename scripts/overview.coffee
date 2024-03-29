ReportTab = require 'reportTab'
templates = require '../templates/templates.js'

_partials = require '../node_modules/seasketch-reporting-api/templates/templates.js'

partials = []
for key, val of _partials
  partials[key.replace('node_modules/seasketch-reporting-api/', '')] = val

class OverviewTab extends ReportTab
  # this is the name that will be displayed in the Tab
  name: 'Overview'
  className: 'overview'
  timeout: 120000
  template: templates.overview
  dependencies: [
    'SwimPontoon'
  ]

  render: () ->

    size = @recordSet('SwimPontoon', 'DistanceFromShore').float('SIZE')
    new_size =  @addCommas size
    
    dist_to_shore = @recordSet('SwimPontoon', 'DistanceFromShore').raw('SHORELINE')
    shipping = @recordSet('SwimPontoon', 'DistanceFromShore').raw('SHIPPING')

    if shipping == "Yes"
      shipping = true
    else
      shipping = false
    try
      depth =  @recordSet('SwimPontoon', 'DistanceFromShore').raw('AVG_DEPTH')
    catch
      depth = "unknown"

    if depth == -1 
      depth = "unknown"
    else
      depth = depth+" meters"
    isCollection = @model.isCollection()

    #show tables instead of graph for IE
    if window.d3
      d3IsPresent = true
    else
      d3IsPresent = false

    attributes = @model.getAttributes()
    
    context =
      sketch: @model.forTemplate()
      sketchClass: @sketchClass.forTemplate()
      attributes: @model.getAttributes()
      anyAttributes: @model.getAttributes().length > 0
      admin: @project.isAdmin window.user
      dist_to_shore: dist_to_shore

      size: new_size
      depth: depth
      isCollection: isCollection
      d3IsPresent: d3IsPresent
      crossesShippingChannel: shipping

    @$el.html @template.render(context, partials)
    @enableLayerTogglers()
    @drawViz(dist_to_shore)
    
  addCommas: (num_str) =>
    num_str += ''
    x = num_str.split('.')
    x1 = x[0]
    x2 = if x.length > 1 then '.' + x[1] else ''
    rgx = /(\d+)(\d{3})/
    while rgx.test(x1)
      x1 = x1.replace(rgx, '$1' + ',' + '$2')
    return x1 + x2

  drawViz: (dist_to_shore) ->
    if window.d3
      el = @$('.viz2')[0]
      maxScale = d3.max([5000 * 1.2])
      ranges = [
        {
          name: 'Warmup'
          start: 0
          end: 1000
          bg: "#8e5e50"
          class: 'easy'
        }
        {
          name: 'Serious'
          start: 1000
          end: 3000
          bg: '#588e3f'
          class: 'serious'
        }
        {
          name: 'Triathlon'
          start: 3000
          end: maxScale
          class: 'triathlon'
        }
      ]

      x = d3.scale.linear()
        .domain([0, maxScale])
        .range([0, 400])
      if dist_to_shore > maxScale
        dist_to_shore = maxScale
      chart = d3.select(el)
      chart.selectAll("div.range")
        .data(ranges)
      .enter().append("div")
        .style("width", (d) -> x(d.end - d.start) + 'px')
        .attr("class", (d) -> "range " + d.class)
        .append("span")
          .text((d) -> d.name)
          .append("span")
            .text (d) ->
              if d.class is 'above'
                "> #{d.start} m"
              else
                "#{d.start}-#{d.end} m"

      chart.selectAll("div.dist_to_shore")
        .data([dist_to_shore])
      .enter().append("div")
        .attr("class", "dist_to_shore")
        .style("left", (d) -> x(d) + 'px')
        .text((d) -> "")



module.exports = OverviewTab