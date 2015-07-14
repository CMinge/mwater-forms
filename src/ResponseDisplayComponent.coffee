React = require 'react'
H = React.DOM
formUtils = require './formUtils'
ImageDisplayComponent = require './ImageDisplayComponent'
EntityDisplayComponent = require './EntityDisplayComponent'
EntityLoadingComponent = require './EntityLoadingComponent'
moment = require 'moment'

# Static view of a response
module.exports = class ResponseDisplayComponent extends React.Component
  @propTypes:
    form: React.PropTypes.object.isRequired
    response: React.PropTypes.object.isRequired
    formCtx: React.PropTypes.object.isRequired
    locale: React.PropTypes.string # Defaults to english
    T: React.PropTypes.func  # Localizer to use. Call form compiler to create one

  handleLocationClick: (location) ->
    if @props.formCtx.displayMap
      @props.formCtx.displayMap(location)

  # Header which includes basics
  renderHeader: ->
    H.div null,
      H.div key: "user", 
        @props.T('User'), ": ", H.b(null, @props.response.user)
      H.div key: "code", 
        @props.T('Response Id'), ": ", H.b(null, @props.response.code)
      H.div key: "date", 
        @props.T('Date'), ": ", H.b(null, moment(@props.response.modified.on).format('llll'))

  renderLocation: (location) ->
    if location
      return H.div null, 
        H.a onClick: @handleLocationClick.bind(this, location), style: { cursor: "pointer" },
          "#{location.latitude}\u00B0 #{location.longitude}\u00B0"
          if location.accuracy then "(+/-) #{location.accuracy} m"

  renderAnswer: (q, answer) ->
    if not answer
      return null

    # Handle alternates
    if answer.alternate
      switch answer.alternate 
        when "na"
          return H.em null, @props.T("Not Applicable")
        when "dontknow"
          return H.em null, @props.T("Don't Know")

    if not answer.value?
      return null

    switch formUtils.getAnswerType(q)
      when "text", "number"
        return "" + answer.value
      when "choice"
        choice = _.findWhere(q.choices, { id: answer.value })
        if choice
          label = formUtils.localizeString(choice.label, 'en')
          if answer.specify?
            specify = answer.specify[answer.value]
          else
            specify = null

          return H.div null,
            label
            if specify 
              ": "  
              H.em null, specify
        else
          return H.span className: "label label-danger", "Invalid Choice"
      when "choices"
        return _.map answer.value, (v) => 
          choice = _.findWhere(q.choices, { id: v })
          if choice
            return H.div null, 
              formUtils.localizeString(choice.label, 'en')
              if answer.specify? and answer.specify[v]
                ": "
                H.em null, answer.specify[v]
          else 
            return H.div className: "label label-danger", "Invalid Choice"
  
      when "date"
        # Depends on precision
        if answer.value.length <= 7   # YYYY or YYYY-MM
          return H.div null, answer.value
        else if answer.value.length <= 10 # Date
          return H.div null, moment(answer.value).format("LL")
        else
          return H.div null, moment(answer.value).format("LLL")

      when "units"
        if answer.value and answer.value.quantity? and answer.value.units?
          # Find units
          units = _.findWhere(q.units, { id: answer.value.units })

          valueStr = "" + answer.value.quantity
          unitsStr = if units then formUtils.localizeString(units.label, 'en') else "(Invalid)"

          if q.unitsPosition == "prefix" 
            return H.div null,
              H.em null, unitsStr
              " "
              valueStr
          else 
            return H.div null,
              valueStr
              " "
              H.em null, unitsStr

      when "boolean"
        return if answer.value then @props.T("True") else @props.T("False")

      when "location"
        return @renderLocation(answer.value)

      when "image"
        if answer.value
          return React.createElement(ImageDisplayComponent, formCtx: @props.formCtx, id: answer.value.id)

      when "images"
        return _.map answer.value, (img) =>
          React.createElement(ImageDisplayComponent, formCtx: @props.formCtx, id: img.id)

      when "texts"
        return _.map answer.value, (txt) =>
          H.div null, txt

      when "site"
        code = answer.value
        # TODO Eventually always go to code parameter. Legacy responses used code directly as value.
        if code.code
          code = code.code

        return H.div null,
          @props.T("Site")
          ": "
          H.b null, code

      when "entity"
        return React.createElement(EntityLoadingComponent, {
            formCtx: @props.formCtx
            entityId: answer.value
            entityType: q.entityType
            T: @props.T 
            }, React.createElement(EntityDisplayComponent, {
              formCtx: @props.formCtx
              propertyIds: q.displayProperties
              locale: @props.locale
              T: @props.T
              }))

  renderQuestion: (q) ->
    # Get answer
    answer = @props.response.data[q._id]    

    H.tr key: q._id,
      H.td key: "name", style: { width: "50%" },
        formUtils.localizeString(q.text, @props.locale)
      H.td key: "value",
        @renderAnswer(q, answer)
        if answer and answer.timestamp
          H.div null,
            @props.T('Answered')
            ": "
            moment(answer.timestamp).format('llll')
        if answer and answer.location
          @renderLocation(answer.location)

  renderItem: (item) ->
    if item._type == "Section"
      return [
        H.tr key: item._id,
          H.td colSpan: 2, style: { fontWeight: "bold" },
            formUtils.localizeString(item.name, @props.locale)
        _.map item.contents, (item) =>
          @renderItem(item)
      ]

    if formUtils.isQuestion(item)
      return @renderQuestion(item)

  renderContent: ->
    H.table className: "table table-bordered",
      H.tbody null, 
        _.map @props.form.design.contents, (item) =>
          @renderItem(item)

  render: ->
    H.div null,
      @renderHeader()
      @renderContent()
