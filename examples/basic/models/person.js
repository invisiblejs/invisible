'use strict';

var Invisible = require('../../..');

function Person(firstName, lastName, email){
  this.firstName = firstName;
  this.lastName = lastName;
  this.email = email;
}

Person.prototype.fullName = function(){
  return this.firstName + ' ' + this.lastName;
};

module.exports = Invisible.createModel('Person', Person);
