# update ball position

speedY = speedY + accY

y = y + speedY
x = x + speedX

edge = w/2.0 - r

if (x < -edge):
    x = -edge
    speedX = -speedX
if (x > edge):
    x = edge
    speedX = -speedX

if (y < -edge):
    y = -edge
    speedY = -speedY
if (y > edge):
    y = edge
    speedY = -speedY