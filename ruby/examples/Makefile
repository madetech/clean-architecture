all: test

build:
	docker build -t app .

test: build
	docker run -t app rspec
