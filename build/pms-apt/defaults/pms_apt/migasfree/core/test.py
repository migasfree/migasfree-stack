

# Sample from backend
# su -c "python3" www-data

from celery import Celery
BROKER_URL='redis://datastore:6379/0'    
BACKEND=BROKER_URL
app = Celery('migasfree', broker=BROKER_URL,  backend=BACKEND)
app.send_task('migasfree.core.tasks.create_repository_metadata', args=[5], kwargs={})

