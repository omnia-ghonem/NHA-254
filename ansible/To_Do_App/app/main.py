from fastapi import FastAPI, Request, Form
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from prometheus_fastapi_instrumentator import Instrumentator



app = FastAPI()

Instrumentator().instrument(app).expose(app)

# Serve static files (CSS)
app.mount("/static", StaticFiles(directory="static"), name="static")

templates = Jinja2Templates(directory="templates")

# In-memory task list (no database)
tasks = []

# Helper for generating auto-increment IDs
def get_next_id():
    if tasks:
        return max(task["id"] for task in tasks) + 1
    return 1

@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request, "tasks": tasks})

@app.post("/add", response_class=HTMLResponse)
async def add_task(request: Request, title: str = Form(...)):
    new_task = {
        "id": get_next_id(),
        "title": title,
        "completed": False
    }
    tasks.append(new_task)
    return RedirectResponse(url="/", status_code=303)

@app.post("/delete/{task_id}", response_class=HTMLResponse)
async def delete_task(request: Request, task_id: int):
    global tasks
    tasks = [task for task in tasks if task["id"] != task_id]
    return RedirectResponse(url="/", status_code=303)

@app.post("/toggle/{task_id}", response_class=HTMLResponse)
async def toggle_task(request: Request, task_id: int):
    for task in tasks:
        if task["id"] == task_id:
            task["completed"] = not task["completed"]
            break
    return RedirectResponse(url="/", status_code=303)

