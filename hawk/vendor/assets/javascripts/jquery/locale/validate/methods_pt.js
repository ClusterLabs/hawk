/*! jQuery Validation Plugin - v1.13.1 - 10/14/2014
 * http://jqueryvalidation.org/
 * Copyright (c) 2014 Jörn Zaefferer; Licensed MIT */
!function(a){"function"==typeof define&&define.amd?define(["jquery","../../validate"],a):a(jQuery)}(function(a){a.extend(a.validator.methods,{date:function(a,b){return this.optional(b)||/^\d\d?\/\d\d?\/\d\d\d?\d?$/.test(a)}})});
