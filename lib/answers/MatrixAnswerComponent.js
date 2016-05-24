var H, MatrixAnswerComponent, MatrixColumnCellComponent, R, React, formUtils,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

React = require('react');

H = React.DOM;

R = React.createElement;

formUtils = require('../formUtils');

MatrixColumnCellComponent = require('../MatrixColumnCellComponent');

module.exports = MatrixAnswerComponent = (function(superClass) {
  extend(MatrixAnswerComponent, superClass);

  function MatrixAnswerComponent() {
    this.handleCellChange = bind(this.handleCellChange, this);
    return MatrixAnswerComponent.__super__.constructor.apply(this, arguments);
  }

  MatrixAnswerComponent.contextTypes = {
    locale: React.PropTypes.string
  };

  MatrixAnswerComponent.propTypes = {
    items: React.PropTypes.arrayOf(React.PropTypes.shape({
      id: React.PropTypes.string.isRequired,
      label: React.PropTypes.object.isRequired,
      hint: React.PropTypes.object
    })).isRequired,
    contents: React.PropTypes.array.isRequired,
    value: React.PropTypes.object,
    onValueChange: React.PropTypes.func.isRequired,
    data: React.PropTypes.object,
    parentData: React.PropTypes.object,
    formExprEvaluator: React.PropTypes.object.isRequired
  };

  MatrixAnswerComponent.prototype.focus = function() {
    return null;
  };

  MatrixAnswerComponent.prototype.handleCellChange = function(item, column, answer) {
    var change, itemData, matrixValue;
    matrixValue = this.props.value || {};
    itemData = matrixValue[item.id] || {};
    change = {};
    change[column._id] = answer;
    itemData = _.extend({}, itemData, change);
    change = {};
    change[item.id] = itemData;
    matrixValue = _.extend({}, matrixValue, change);
    return this.props.onValueChange(matrixValue);
  };

  MatrixAnswerComponent.prototype.renderColumnHeader = function(column, index) {
    return H.th({
      key: column._id
    }, formUtils.localizeString(column.text, this.context.locale), column.required ? H.span({
      className: "required"
    }, "*") : void 0);
  };

  MatrixAnswerComponent.prototype.renderHeader = function() {
    return H.thead(null, H.tr(null, H.th(null), _.map(this.props.contents, (function(_this) {
      return function(column, index) {
        return _this.renderColumnHeader(column, index);
      };
    })(this))));
  };

  MatrixAnswerComponent.prototype.renderCell = function(item, itemIndex, column, columnIndex) {
    var cellAnswer, invalid, itemData, matrixValue;
    matrixValue = this.props.value || {};
    itemData = matrixValue[item.id] || {};
    cellAnswer = itemData[column._id] || {};
    invalid = false;
    return R(MatrixColumnCellComponent, {
      key: column._id,
      column: column,
      data: this.props.data,
      parentData: this.props.parentData,
      answer: cellAnswer,
      onAnswerChange: this.handleCellChange.bind(null, item, column),
      formExprEvaluator: this.props.formExprEvaluator,
      invalid: invalid
    });
  };

  MatrixAnswerComponent.prototype.renderItem = function(item, index) {
    return H.tr({
      key: index
    }, H.td({
      key: "_item"
    }, H.label(null, formUtils.localizeString(item.label, this.context.locale)), item.hint ? [
      H.br(), H.div({
        className: "text-muted"
      }, formUtils.localizeString(item.hint, this.context.locale))
    ] : void 0), _.map(this.props.contents, (function(_this) {
      return function(column, columnIndex) {
        return _this.renderCell(item, index, column, columnIndex);
      };
    })(this)));
  };

  MatrixAnswerComponent.prototype.render = function() {
    return H.table({
      className: "table"
    }, this.renderHeader(), H.tbody(null, _.map(this.props.items, (function(_this) {
      return function(item, index) {
        return _this.renderItem(item, index);
      };
    })(this))));
  };

  return MatrixAnswerComponent;

})(React.Component);