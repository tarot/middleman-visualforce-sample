#=require "jquery"
#=require "bootstrap"

$ ->
  render_results = (results) ->
    html = results.map (e) ->
      "<a class=\"card\" href=\"/#{e.Id}\"><div class=\"card-heading\">#{e.Name}</div><ul class=\"card-detail\"><li>#{e.Email}</li><li>#{e.Phone}</li></ul></a>"
    $('#queryresult').empty().append html.join ''

  $('#remoting').on 'click', (event) ->
    query = "%#{$('[name="remoting_query"]').val()}%"
    Visualforce.remoting.Manager.invokeAction 'SampleController.sampleAction', query, (result, status) ->
      render_results result
    , escape: false

  $('#remoteobject').on 'click', (event) ->
    like_query = "%#{$('[name="remoting_query"]').val()}%"
    condition = or:
      or:
        FirstName: like: like_query
        LastName: like: like_query
      Email:
        like: like_query
    new SObjectModel.Contact().retrieve where: condition, limit: 100, (error, results) ->
      results = results.map (e) ->
        Id: e.get 'Id'
        Name: e.get 'Name'
        Email: e.get 'Email'
        Phone: e.get 'Phone'
      render_results results
