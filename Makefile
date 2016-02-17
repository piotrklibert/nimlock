
slock: src/*.nim src/*.cfg
	nimble build
	sudo chown root:root slock
	sudo chmod u+s slock
