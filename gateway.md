# Gateway

The responsibility of a gateway is to adapt an IO mechanism for your [Use Cases](use_case.md).

Usually, a gateway will be the adapter between a data source (e.g. Postgresql) and a particular [Domain](domain.md) object (e.g. Order)

In Object-Oriented languages a gateways are usually a class which implements an interface.

IO is could be anything external to your application e.g. files, database or even HTTP API calls

It is the responsibility of Gateways to (one or more of):

* Construct Domain objects by reading from the I/O source
* Accept Domain objects to be written to the I/O source

Gateways are I/O source specific e.g. ActiveRecord, Sequel, MySQL, Paypal, FileSystem, RethinkDB
