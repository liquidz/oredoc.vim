.PHONY: vitalize test doc lint clean
PLUGIN_NAME = oredoc
VITAL_MODULES = Process

vitalize:
	vim -c "Vitalize . --name=$(PLUGIN_NAME) $(VITAL_MODULES)" -c q

test:
	themis

doc:
	vimdoc .

lint:
	find . -name "*.vim" | grep -v vital | xargs beco vint

clean:
	/bin/rm -rf autoload/vital*
