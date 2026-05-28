# Cleanup 
# Run as root, of course. 

cd /var/log

# Clear "messages"  
cat /dev/null > messages

# Clear "wtmp" 
cat /dev/null > wtmp

echo "Log files cleaned up" 

