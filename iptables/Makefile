all: firewall.sh

khan-forward.sh: Makefile khan-forward.firewall
	../firewall khan-forward.firewall load/torrent  >khan-forward.sh
	chmod u+x khan-forward.sh

xonotic.sh: Makefile ../lib/xonotic.firewall
	cd ../ && ./firewall lib/xonotic.firewall load/server  >netbox/xonotic.sh
	chmod u+x xonotic.sh

ps4.sh: Makefile ps4.firewall
	../firewall ps4.firewall load >ps4.sh
	chmod u+x ps4.sh

firewall.sh: Makefile netbox.firewall khan-forward.sh xonotic.sh ps4.sh
	../firewall netbox.firewall load >firewall.sh
	chmod u+x firewall.sh


install: firewall.sh
	sudo cp *.sh /usr/local/sys

clean:
	@rm -f *.sh
