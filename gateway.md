# Gateways

Contains IO adapters (e.g. files, database or API calls)

It is the responsibility of Gateways to (one or more of):

* Construct Domain objects by reading from the I/O source
* Accept Domain objects to be written to the I/O source

Gateways are I/O source specific e.g. ActiveRecord, Sequel, MySQL, Paypal, FileSystem, RethinkDB
