# Beetle makefile

default: format test coveralls docs


format:
	mix format


test: format
	mix test


dialyzer:
	mix dialyzer


dialyzer-ci:
	mix dialyzer --halt-exit-status


docs:
	mix docs


coveralls:
	mix coveralls


.PHONY: format test coveralls docs
