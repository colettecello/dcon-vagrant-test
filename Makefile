default: up

up:
	vagrant up | tee -a logs/log.txt

clean:
	vagrant destroy -f

provision: up
	vagrant provision | tee -a logs/log.txt
