Luca.components.GridView = Luca.View.extend
  events:
    "dblclick .grid-view-row" : "double_click_handler"
    "click .grid-view-row": "click_handler"

  className: 'luca-ui-grid-view'

  scrollable: true

  emptyText: 'No Results To display'

  # available options are striped, condensed, bordered
  # or any combination of these, split up by space
  tableStyle: 'striped'

  hooks:[
    "before:grid:render",
    "before:render:header",
    "before:render:row",
    "after:grid:render",
    "row:double:click",
    "row:click",
    "after:collection:load"
  ]

  initialize: (@options={})->
    _.extend @, @options
    _.extend @, Luca.modules.Deferrable

    Luca.View::initialize.apply( @, arguments )

    _.bindAll @, "double_click_handler", "click_handler"

    @configure_collection()

    @collection.bind "reset", (collection) =>
      @refresh()
      @trigger "after:collection:load", collection

  beforeRender: ()->
    @trigger "before:grid:render", @

    @$el.addClass 'scrollable-grid-view' if @scrollable

    @$el.html Luca.templates["components/grid_view"]()

    @table  = $('table.luca-ui-grid-view', @el)
    @header = $("thead", @table)
    @body   = $("tbody", @table)
    @footer = $("tfoot", @table)

    if Luca.enableBootstrap
      @table.addClass('table')

    _( @tableStyle?.split(" ") ).each (style)=>
      @table.addClass("table-#{ style }")

    @setDimensions() if @scrollable

    @renderHeader()

    @emptyMessage()

    @renderToolbars()

    $(@container).append @$el

  toolbarContainers:(position="bottom")->
    $(".toolbar-container.#{ position }", @el)

  renderToolbars: ()->
    _( @toolbars ).each (toolbar)=>
      toolbar = Luca.util.lazyComponent(toolbar)
      toolbar.container = @toolbarContainers( toolbar.position )
      toolbar.render()

  setDimensions: (offset)->
    @height ||= 285

    $('.grid-view-body', @el).height( @height )
    $('tbody.scrollable', @el).height( @height - 23 )

    @container_width = do => $(@container).width()
    @width = if @container_width > 0 then @container_width else 756

    #@width += offset if offset

    $('.grid-view-body', @el).width( @width )
    $('.grid-view-body table', @el).width( @width )

    @setDefaultColumnWidths()

  resize: (newWidth)->
    difference = newWidth - @width
    @width = newWidth

    $('.grid-view-body', @el).width( @width )
    $('.grid-view-body table', @el).width( @width )

    if @columns.length > 0
      distribution = difference / @columns.length

      _(@columns).each (col,index)=>
        column = $(".column-#{ index }", @el )
        column.width( col.width = col.width + distribution )

  padLastColumn: ()->
    configured_column_widths = _(@columns).inject (sum, column)->
      sum = (column.width) + sum
    , 0

    unused_width = @width - configured_column_widths

    if unused_width > 0
      @lastColumn().width += unused_width

  setDefaultColumnWidths: ()->
    default_column_width = if @columns.length > 0 then @width / @columns.length else 200

    _( @columns ).each (column)->
      parseInt(column.width ||= default_column_width)

    @padLastColumn()


  lastColumn: ()->
    @columns[ @columns.length - 1 ]

  afterRender: ()->
    @refresh()
    @trigger "after:grid:render", @

  emptyMessage: (text="")->
    text ||= @emptyText
    @body.html('')
    @body.append Luca.templates["components/grid_view_empty_text"](colspan:@columns.length,text:text)

  refresh: ()->
    @body.html('')
    @collection.each (model,index)=>
      @render_row.apply(@, [model,index])

    if @collection.models.length == 0
      @emptyMessage()

  ifLoaded: (fn, scope)->
    scope ||= @
    fn ||= ()-> true

    @collection.ifLoaded(fn,scope)

  applyFilter: (values, options={auto:true,refresh:true})->
    @collection.applyFilter(values, options)

  renderHeader: ()->
    @trigger "before:render:header"

    headers = _(@columns).map (column,column_index) =>
      # temporary hack for scrollable grid dimensions.
      style = if column.width then "width:#{ column.width }px;" else ""

      "<th style='#{ style }' class='column-#{ column_index }'>#{ column.header}</th>"

    @header.append("<tr>#{ headers }</tr>")

  render_row: (row,row_index)->
    model_id = if row?.get and row?.attributes then row.get('id') else ''

    @trigger "before:render:row", row, row_index

    cells = _( @columns ).map (column,col_index) =>
      value = @cell_renderer(row, column, col_index)
      style = if column.width then "width:#{ column.width }px;" else ""

      display = if _.isUndefined(value) then "" else value

      "<td style='#{ style }' class='column-#{ col_index }'>#{ display }</td>"

    if @alternateRowClasses
      alt_class = if row_index % 2 is 0 then "even" else "odd"

    @body?.append("<tr data-record-id='#{ model_id }' data-row-index='#{ row_index }' class='grid-view-row #{ alt_class }' id='row-#{ row_index }'>#{ cells }</tr>")

  cell_renderer: (row, column, columnIndex )->
    if _.isFunction column.renderer
      return column.renderer.apply @, [row,column,columnIndex]
    else if column.data.match(/\w+\.\w+/)
      source = row.attributes || row
      return Luca.util.nestedValue( column.data, source )
    else
      return row.get?( column.data ) || row[ column.data ]

  double_click_handler: (e)->
    me = my = $( e.currentTarget )
    rowIndex = my.data('row-index')
    record = @collection.at( rowIndex )
    @trigger "row:double:click", @, record, rowIndex

  click_handler: (e)->
    me = my = $( e.currentTarget )
    rowIndex = my.data('row-index')
    record = @collection.at( rowIndex )
    @trigger "row:click", @, record, rowIndex

    $('.grid-view-row', @body ).removeClass('selected-row')
    me.addClass('selected-row')

Luca.register "grid_view","Luca.components.GridView"
