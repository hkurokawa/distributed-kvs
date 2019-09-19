.PHONY: status start stop start-1 stop-1 restart clean

status:
	pgrep -f my-app.rb
	ss -tapn | grep -e '3000\|3001\|3002'

start:
	nohup bundle exec ruby my-app.rb -p 3000 >> log.txt 2>&1 &
	nohup bundle exec ruby my-app.rb -p 3001 >> log.txt 2>&1 &
	nohup bundle exec ruby my-app.rb -p 3002 >> log.txt 2>&1 &

stop:
	pkill -9 -f my-app.rb

start-1:
	nohup bundle exec ruby my-app.rb -p 3000 >> log.txt 2>&1 &

stop-1:
	pkill -9 -f 'my-app.rb -p 3000'

restart: stop start

clean:
	rm -f data-*.json
	rm -f log.txt
