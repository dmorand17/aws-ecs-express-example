import random

from fastapi import FastAPI

tags_metadata = [
    {
        "name": "Random Playground",
        "description": "Generate random numbers",
    },
    {
        "name": "Random Items Management",
        "description": "Create, shuffle, read, update and delete items",
    },
]

app = FastAPI(
    title="Randomizer API",
    description="Shuffle lists, pick random items, and generate random numbers.",
    version="1.0.0",
    openapi_tags=tags_metadata,
)


@app.get("/", tags=["Random Playground"])
async def home():
    return {"message": "Welcome to the Randomizer API"}


@app.get("/random/{max_value}")
def get_random_number(max_value: int):
    return {"max": max_value, "random_number": random.randint(1, max_value)}
