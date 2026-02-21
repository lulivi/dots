default: print

p: print
l: link
d: delete

pa: print-all
la: link-all
da: delete-all

lf: link-force
df: delete-force

print:
	./automation/backstore.py --print

link:
	./automation/backstore.py --link

delete:
	./automation/backstore.py --delete

print-all:
	./automation/backstore.py --print --all

link-all:
	./automation/backstore.py --link --all

delete-all:
	./automation/backstore.py --delete --all

link-force:
	./automation/backstore.py --link --force

delete-force:
	./automation/backstore.py --delete --force
