isFunction = (o) -> typeof o == 'function'
isArrayLike = (o) -> typeof o?.length == 'number'
isObject = (o) -> o? && typeof o == 'object' && !isArrayLike(o)
noop = -> return

send = do (seq = 0) ->
  (action, params, callback) ->
    xhr = new XMLHttpRequest()
    xhr.open 'POST', "/apexremote/#{action}/#{seq++}", true
    xhr.onreadystatechange = ->
      return unless xhr.readyState == 4
      try
        throw new Error() unless xhr.status == 200
        callback null, JSON.parse xhr.responseText, status: true, statusCode: 200
      catch error
        callback error, [], status: false, statusCode: 200
    xhr.setRequestHeader 'Content-Type', 'application/json'
    xhr.send JSON.stringify params

class SObjectModel
  constructor: (@name, @_props = {}) ->
    return

  send: (method, params, callback) ->
    send "JavaScriptSObjectBaseController.#{@name}.#{method}", params, callback

  get: (name) ->
    @_props[name]

  set: (prop_name, value) ->
    @_props[name] = value
    return

  retrieve: (criteria, callback)->
    switch
      when isFunction(callback)
        @send 'retrieve', criteria: criteria, (error, result, status) =>
          result = result?.map (e) => new @constructor(e)
          callback error, result, status
      when isFunction(criteria)
        @retrieve null, criteria
      else
        throw new Error()

  update: (ids, value, callback) ->
    switch
      when isFunction(callback)
        @send 'update', ids: ids, value: value, callback
      when isFunction(value)
        @update null, ids, value
      when isObject(ids)
        @update null, ids, noop
      else
        @update null, @_props, (error, result, status) =>
          @_props.Id = result[0].Id if result?[0]?.Id?
          (ids ? noop)(error, result, status)

  upsert: (value, callback) ->
    switch
      when isFunction(callback)
        @send 'upsert', value: value, callback
      when isObject(value)
        @upsert value, noop
      else
        @upsert @_props, (error, result, status) =>
          @_props.Id = result[0].Id if result?[0]?.Id?
          (value ? noop)(error, result, status)

  del: (ids, callback) ->
    switch
      when isFunction(callback)
        @send 'del', ids: ids, callback
      when isArrayLike(ids)
        @del ids, noop
      else
        @del [@_props.Id], ids ? noop

  create: (value, callback) ->
    switch
      when isFunction(callback)
        @send 'create', value: value, callback
      when isObject(value)
        @create value, noop
      else
        @create @_props, (error, result, status) =>
          @_props.Id = result[0].Id if result?[0]?.Id?
          (value ? noop).apply null, arguments

for sobject in ['Contact', 'Account']
  SObjectModel[sobject] = class extends SObjectModel
    constructor: (props) -> super sobject, props

window.SObjectModel = SObjectModel

window.Visualforce = remoting: Manager: invokeAction: (action, args...) ->
  callback = if isFunction(args[args.length - 1])
    args.pop
  else if isFunction(args[args.length - 2])
    args.splice(args.length - 2, 1)[0]
  else noop
  send action, args, (error, result, status) ->
    status.message = error if error?
    callback result, status