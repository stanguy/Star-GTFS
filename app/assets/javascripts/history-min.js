/*
 By Filipe Fortes ( www.fortes.com )
 MIT License
*/
window.b=window.b||{g:100,d:"-"};if(document.location.hash){var g=document.location.hash[0]==="#"?document.location.hash.substr(1):document.location.hash;if(g[0]===window.b.d&&g.length>=2){g=g.substr(1);document.location=g}}
(function(a,d,h){function i(c,f,e,k){e=a.d+escape(e);a.h(e,{i:c,title:f});a.hash=e;if(k)h.replace("#"+e);else h.hash="#"+e}if(!("pushState"in d.history)){var j=document.documentMode&&document.documentMode<=7;if("sessionStorage"in d&&d.JSON&&!j){a.h=function(c,f){d.sessionStorage[c]=JSON.stringify(f)};a.f=function(c){return JSON.parse(d.sessionStorage[c])}}else{a.e={};a.h=function(c,f){a.e[c]=f};a.f=function(c){return a.e[c]}}d.history.pushState=function(c,f,e){i(c,f,e,false)};d.history.replaceState=
function(c,f,e){i(c,f,e,true)};a.c=function(){return h.hash[0]==="#"?h.hash.substring(1):h.hash};a.a=function(){var c=a.c();if(c!==a.hash){a.hash=c;c=a.hash?a.f(a.hash):{};if("onpopstate"in d&&typeof d.onpopstate==="function")d.onpopstate.apply(d,[{state:c?c.i:null}])}};if("onhashchange"in d&&!j)d.onhashchange=a.a;else a.g=setInterval(function(){a.c()!==a.hash&&a.a()},a.g);a.c()&&a.a()}})(window.b,window,document.location);
