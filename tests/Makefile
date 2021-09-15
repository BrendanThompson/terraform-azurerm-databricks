timeout = 60m

unit: unit-test
unit-test:
	go test -timeout $(timeout) -tags=unit -v

integration: integration-test
integration-test:
	go test -timeout $(timeout) -tags=integration -v

test: unit-test integration-test
