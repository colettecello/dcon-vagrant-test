# TODO

1. get vagrant provisioner to start app server as a service
	* install gunicorn
	* write gunicorn config file to tell it where to find
	  the wsgi app it is going to run
	* start gunicorn (it will run on some high port)
	* set up apache or nginx to proxy to gunicorn
1. set up a caching layer (varnish et c)
1. try out ansible

