# Collection Loader View is a simple modal view
# You can provide your own template for the collection loader modal
# if you want to. Default implementation uses twitter bootstrap modal and
# progress bar (http://twitter.github.com/bootstrap/). You template
# should have contain `progress`, `bar` and `message` classes
Luca.components.CollectionLoaderView = Luca.components.Template.extend
  className: 'luca-ui-collection-loader-view'

  template: "components/collection_loader_view"

  initialize: (@options={})->
    Luca.components.Template::initialize.apply @,arguments

    @container ||= $('body')
    @manager   ||= Luca.CollectionManager.get()

    @setupBindings()

  modalContainer: ()->
    $("#progress-modal", @el)

  setupBindings: ()->
    @manager.bind "collection_loaded", (name)=>
      loaded   = @manager.loadedCollectionsCount()
      total    = @manager.totalCollectionsCount()
      progress = parseInt((loaded / total) * 100)

      @modalContainer().find('.progress .bar').attr("style", "width: #{progress}%;")
      @modalContainer().find('.message').html("Loaded #{ _(name).chain().humanize().titleize().value() }...")

    @manager.bind "all_collections_loaded", ()=>
      @modalContainer().find('.message').html("All done!")
      _.delay ()=>
        @modalContainer().modal('hide')
      , 400

Luca.register "collection_loader_view","Luca.components.CollectionLoaderView"