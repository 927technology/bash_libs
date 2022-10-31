function test.loop {
	for i in {1..100}; do
		echo ${i}
		sleep 1
	done
}
function test.return {
	echo test
	sleep 10
}
