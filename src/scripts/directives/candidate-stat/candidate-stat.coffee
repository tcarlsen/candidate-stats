.directive "candidateStat", ($filter) ->
  restrict: "A"
  scope: true
  templateUrl: "candidate-stat.html"
  link: (scope, element, attrs) ->
    groupCount = 0
    groupTotal = 0
    labelCount = 0

    pointIsInArc = (pt, ptData, d3Arc) ->
      r1 = d3Arc.innerRadius()(ptData)
      r2 = d3Arc.outerRadius()(ptData)
      theta1 = d3Arc.startAngle()(ptData)
      theta2 = d3Arc.endAngle()(ptData)
      dist = pt.x * pt.x + pt.y * pt.y
      angle = Math.atan2(pt.x, -pt.y)
      angle = if angle < 0 then angle + Math.PI * 2 else angle

      return r1 * r1 <= dist and dist <= r2 * r2 and theta1 <= angle and angle <= theta2

    render = (results) ->
      base = d3.select(element[0])
      container = base.select(".chart-left-column")
      containerWidth = container[0][0].offsetWidth
      containerHeight = container[0][0].offsetHeight

      if attrs.type is "text"
        scope.textView = true

      else if attrs.type is "column"
        maxValue = d3.max results[2015], (d) -> parseFloat d.value_pct
        svg =
          ele: base.select ".chart-svg"
          top: 50
          left: 45
          bottom: 70
          height: -> containerHeight - @top - @bottom
          width: -> containerWidth - (@left * 2)
        yScale = d3.scale
          .linear()
          .domain [0, maxValue]
          .range [svg.height(), 0]

        yAxis = d3.svg.axis()
          .scale(yScale)
          .ticks 3
          .tickSize(-svg.width(), 0, 0)
          .tickFormat (d) -> "#{d}%"
          .orient "left"

        columnMargin = 5
        groupMargin = 60
        columnWidth = ((svg.width() - columnMargin - (groupMargin * groupTotal)) / (labelCount * groupTotal)) - columnMargin
        groupWidth = svg.width() / groupTotal

        draw = svg.ele.append "g"
          .attr "transform", "translate(#{svg.left}, #{svg.top})"

        draw.append "g"
          .attr "class", "y axis"
          .call yAxis

        for key, value of results
          columnPadding = (groupWidth * groupCount) + (groupMargin / groupTotal)

          column = draw.selectAll(".column.g-#{groupCount}").data(value)

          column
            .enter()
              .append "rect"
                .attr "class", (d, i) -> "column g-#{groupCount} c-#{(i + 1)}"
                .attr "height", 0
                .attr "y", svg.height()

          column
            .attr "width", columnWidth
            .attr "x", (d, i) -> columnPadding + (columnWidth * i) + (columnMargin * (i + 1))
            .transition().duration(1000)
              .attr "height", (d) -> svg.height() - yScale(d.value_pct + 1)
              .attr "y", (d) -> yScale(d.value_pct + 1)

          texts = draw.selectAll(".text.g-#{groupCount}").data(value)

          texts
            .enter()
              .append "text"
                .attr "class", "text g-#{groupCount}"
                .attr "text-anchor", "middle"

          texts
            .text (d) ->
              pct = $filter("number")(d.value_pct, 1)

              return "#{pct}%"

          if columnWidth > 25
            texts
              .attr "y", svg.height()
              .attr "x", (d, i) -> columnPadding + (columnWidth * i) + (columnMargin * (i + 1)) + (columnWidth / 2)
              .transition().duration(1000)
                .attr "y", (d) -> yScale(d.value_pct) - 7
          else
            texts
              .attr "x", -> -svg.height()
              .attr "transform", "rotate(-90)"
              .attr "y", (d, i) -> columnPadding + (columnWidth * i) + (columnMargin * (i + 1)) + (columnWidth / 2) + 3
              .transition().duration(1000)
                .attr "x", (d) -> -yScale(d.value_pct) + 25

          draw.append "text"
            .attr "class", "label"
            .attr "text-anchor", "middle"
            .attr "y", containerHeight - 80
            .attr "x", columnPadding + (groupWidth / 2) - (groupMargin / groupTotal)
            .text "#{key}"

          groupCount += 1

      else if attrs.type is "pie"
        svg =
          ele: base.select ".chart-svg"
          top: 25
          left: 45
          bottom: 60
          height: -> containerHeight - @bottom
          width: -> containerWidth
        groupWidth = svg.width() / groupTotal
        radius = (svg.height() / 2) - svg.top
        radius = groupWidth - 20 if groupWidth < radius
        labelsVisible = []
        pie = d3.layout.pie()
          .sort null
          .value (d) -> d.value_pct
        arc = d3.svg.arc()
          .outerRadius radius
          .innerRadius 20

        for key, value of results
          labelsVisible[key] = []
          allLabelsVisible = true
          groupX = (groupWidth * groupCount) + (groupWidth / 2)

          draw = svg.ele.append "g"
            .attr "transform", "translate(#{(groupX)}, #{(svg.height() / 2)})"
            .data([value])

          slices = draw.selectAll(".slice").data(pie)

          slices
          .enter()
            .append "path"
              .attr "class", (d, i) -> "slice c-#{(i + 1)}"

          slices
            .transition().duration(1000)
              .attr "d", arc

          texts = draw.selectAll(".text").data(pie)

          texts
            .enter()
              .append "text"
                .attr "class", (d, i) -> "text pie key-#{i}"
                .attr "text-anchor", "middle"

          texts
            .text (d) ->
              pct = $filter("number")(d.data.value_pct, 1)
              return "#{pct}%"
            .each (d, i) ->
              bb = @getBBox()
              center = arc.centroid(d)
              topLeft =
                x: center[0] + bb.x
                y: center[1] + bb.y
              topRight =
                x: topLeft.x + bb.width
                y: topLeft.y
              bottomLeft =
                x: topLeft.x
                y: topLeft.y + bb.height
              bottomRight =
                x: topLeft.x + bb.width
                y: topLeft.y + bb.height
              d.visible = pointIsInArc(topLeft, d, arc) and pointIsInArc(topRight, d, arc) and pointIsInArc(bottomLeft, d, arc) and pointIsInArc(bottomRight, d, arc)
              labelsVisible[key][i] = d.visible
              allLabelsVisible = false if d.visible is false
            .attr "display", (d) -> if d.visible then null else 'none'
            .transition().duration(1000)
              .attr "transform", (d) -> "translate(#{arc.centroid(d)})"

          if !allLabelsVisible
            if !tip
              tip = d3.tip()
                .attr "class", "d3-tip"
                .html (d) ->
                  pct = $filter("number")(d.data.value_pct, 1)

                  return "#{pct}%"

              draw.call(tip)

            slices
              .attr "data-key", key
              .on "mouseover", (d, i) ->
                keyValue = d3.select(this).attr("data-key")
                visible = labelsVisible[keyValue][i]

                if !visible
                  tip.show d
              .on "mouseout", (d, i) ->
                tip.hide()

          draw.append "text"
            .attr "class", "label"
            .attr "text-anchor", "middle"
            .attr "y", svg.height() / 2 + svg.top
            .attr "x", 0
            .text "#{key}"

          groupCount += 1

    waitForStats = scope.$watchCollection "stats", (data) ->
      return if !data
      if data.hasOwnProperty(attrs.candidateStat)
        data = data[attrs.candidateStat]
        groupTotal = Object.keys(data.results).length
        labelCount = data.labels.length

        scope.title = data.category
        scope.values = data.results
        scope.labels = data.labels

        render data.results

        waitForStats()
