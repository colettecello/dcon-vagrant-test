default: up

up:
	vagrant up

clean:
	vagrant destroy -f

provision: up
	vagrant provision
