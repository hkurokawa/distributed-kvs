expect() {
  expected="$1"
  actual="$2"

  if [ "$actual" = "$expected" ]; then 
    echo "PASS"
  else
    echo "FAIL; expected $expected but got $actual"
    exit 1
  fi
}

make clean
make restart

sleep 1
curl -if -d 'tommy' http://localhost:3000/name #=> success
expect 0 $?
res=$(curl -sf http://localhost:3001/name) #=> 'tommy'
expect 0 $?
expect "tommy" $res

make stop-1
curl -if -d 'ujihisa' http://localhost:3000/name #=> fail
expect 7 $?
curl -if -d 'ujihisa' http://localhost:3001/name #=> success
expect 0 $?
curl -if http://localhost:3000/name #=> fail
expect 7 $?
res=$(curl -sf http://localhost:3001/name) #=> 'ujihisa'
expect 0 $?
expect "ujihisa" $res

make start-1
sleep 1
res=$(curl -sf http://localhost:3000/name) #=> 'ujihisa', not 404
expect 0 $?
expect "ujihisa" $res
