import redis
import time
import logging
import websockets
import asyncio
from celery_config import celery_app  # Import the Celery app from celery_config.py
import os
from dotenv import load_dotenv
from celery import Celery, exceptions  # Correctly import exceptions
from celery_config import celery_app  # Import the Celery app from celery_config.py

# 
# Load environment variables from .env file
load_dotenv()

# Configure logging to display info and debug messages
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Redis server configuration
REDIS_HOST = os.getenv('REDIS_HOST')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))  # Default to 6379 if not set
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')

def connect_to_redis():
    try:
        r = redis.StrictRedis(host=REDIS_HOST, port=REDIS_PORT, password=REDIS_PASSWORD, socket_timeout=10)
        r.ping()
        logging.info("Successfully connected to Redis.")
        return r
    except redis.ConnectionError as e:
        logging.error(f"Connection Error: {e}")
        return None

def simulate_long_running_connection(r):
    try:
        logging.info("Simulating long-running connection...")
        r.set('long_run_test', 'testing connection stability')
        for i in range(1, 10001):
            r.get('long_run_test')
            if i % 100 == 0:
                logging.info(f"Completed {i} operations without issue.")
            time.sleep(0.1)  # Simulate some processing time between commands

        logging.info("Completed long-running connection simulation.")
    except redis.ConnectionError as e:
        logging.error(f"Connection Error during long-running test: {e}")

def simulate_high_frequency_commands(r):
    try:
        logging.info("Simulating high-frequency commands...")
        for i in range(1, 10001):
            r.set(f'high_freq_test_{i}', f'value_{i}')
            if i % 100 == 0:
                logging.info(f"Executed {i} high-frequency commands.")
        logging.info("Completed high-frequency command simulation.")
    except redis.ConnectionError as e:
        logging.error(f"Connection Error during high-frequency test: {e}")

def simulate_idle_connection(r):
    try:
        logging.info("Simulating idle connection...")
        r.set('idle_test', 'testing idle connection stability')
        logging.info("Connection will now idle for 2 minutes...")
        time.sleep(120)
        logging.info("Resuming operations after idle period.")
        r.get('idle_test')
        logging.info("Completed idle connection simulation.")
    except redis.ConnectionError as e:
        logging.error(f"Connection Error during idle test: {e}")

async def simulate_websocket_connection():
    uri = "ws://localhost:8000"
    try:
        async with websockets.connect(uri) as websocket:
            logging.info("WebSocket connection established.")
            for i in range(1, 101):
                message = f"Message {i}"
                await websocket.send(message)
                logging.info(f"Sent: {message}")
                response = await websocket.recv()
                logging.info(f"Received: {response}")
                await asyncio.sleep(0.5)
            logging.info("WebSocket connection test completed.")
    except Exception as e:
        logging.error(f"WebSocket Error: {e}")

def simulate_celery_task_execution():
    task_name = "test_task"
    num_executions = 5
    max_retries = 3  # Number of retries for each task
    successful_executions = 0
    execution_times = []

    for i in range(num_executions):
        for attempt in range(max_retries):
            try:
                logging.info(f"Simulating Celery task execution: {task_name} (Attempt {i+1}/{num_executions}, Try {attempt+1}/{max_retries})")
                
                # Start the timer
                start_time = time.time()
                
                # Sending the task to Celery
                result = celery_app.send_task(task_name)
                
                # Wait for the result with an increased timeout
                task_result = result.get(timeout=30)
                
                # Stop the timer
                end_time = time.time()
                execution_time = end_time - start_time
                execution_times.append(execution_time)
                
                # Log the result of the task
                logging.info(f"Task {task_name} (Attempt {i+1}/{num_executions}) completed successfully with result: {task_result} in {execution_time:.2f} seconds")
                successful_executions += 1
                break  # Exit retry loop on success

            except exceptions.TimeoutError:
                logging.error(f"Task {task_name} (Attempt {i+1}/{num_executions}, Try {attempt+1}/{max_retries}) failed due to timeout.")
                if attempt == max_retries - 1:
                    logging.error(f"Max retries reached for task {task_name} (Attempt {i+1}/{num_executions}).")

            except exceptions.NotRegistered:
                logging.error(f"Task {task_name} (Attempt {i+1}/{num_executions}, Try {attempt+1}/{max_retries}) is not registered.")
                if attempt == max_retries - 1:
                    logging.error(f"Max retries reached for task {task_name} (Attempt {i+1}/{num_executions}).")

            except Exception as e:
                logging.error(f"Task {task_name} (Attempt {i+1}/{num_executions}, Try {attempt+1}/{max_retries}) failed: {e}")
                if attempt == max_retries - 1:
                    logging.error(f"Max retries reached for task {task_name} (Attempt {i+1}/{num_executions}).")

    # Summarize the execution
    average_time = sum(execution_times) / len(execution_times) if execution_times else 0
    logging.info(f"Celery task simulation completed: {successful_executions}/{num_executions} tasks succeeded.")
    logging.info(f"Average execution time: {average_time:.2f} seconds")
    
def main():
    r = connect_to_redis()
    if r:
        # Run Redis-related scenarios
        # simulate_long_running_connection(r)
        # simulate_high_frequency_commands(r)
        # simulate_idle_connection(r)

        # Run WebSocket scenario
        # asyncio.run(simulate_websocket_connection())

        # Run Celery scenario
        simulate_celery_task_execution()

        logging.info("All tests completed.")
    else:
        logging.error("Unable to establish a connection to Redis.")

if __name__ == '__main__':
    main()