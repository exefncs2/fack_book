from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Request, Depends, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from io import BytesIO
import base64, json, uuid, asyncio, secrets, jwt, qrcode

# ====== 基本設定 ======
app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

# ====== 常數與密鑰 ======
SECRET_KEY = "your-static-secret-key"  # 不要使用 secrets.token_hex，每次啟動都會變動
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# ====== 資料儲存（可改為 DB / Redis） ======
USERS = {"user1": {"username": "user1", "full_name": "張三", "email": "user1@example.com"}}
active_sessions: Dict[str, Dict] = {}
connected_clients: Dict[str, WebSocket] = {}
POSTS: List["Post"] = []

# ====== 資料模型 ======
class Comment(BaseModel):
    id: int
    username: str
    content: str
    timestamp: str

class CommentCreate(BaseModel):
    content: str

class Post(BaseModel):
    id: int
    username: str
    content: str
    timestamp: str
    comments: List[Comment] = []

class PostCreate(BaseModel):
    content: str

class SessionRequest(BaseModel):
    session_id: str

class LoginResponse(BaseModel):
    username: str
    token: str

# ====== 工具函數 ======
def generate_qr_code(data: str) -> str:
    qr = qrcode.QRCode(version=1, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=10, border=4)
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = BytesIO()
    img.save(buffer)
    return f"data:image/png;base64,{base64.b64encode(buffer.getvalue()).decode()}"

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# ====== 啟動時清理過期會話 ======
@app.on_event("startup")
async def startup_event():
    asyncio.create_task(cleanup_expired_sessions())

async def cleanup_expired_sessions():
    while True:
        now = datetime.utcnow()
        expired = [sid for sid, s in active_sessions.items() if now - s["created_at"] > timedelta(minutes=15)]
        for sid in expired:
            active_sessions.pop(sid, None)
            client = connected_clients.pop(sid, None)
            if client:
                try: await client.close()
                except: pass
        await asyncio.sleep(60)

# ====== 登入頁面產生 QR ======
@app.get("/", response_class=HTMLResponse)
async def login_page(request: Request):
    session_id = str(uuid.uuid4())
    active_sessions[session_id] = {"created_at": datetime.utcnow(), "status": "pending", "user": None}
    qr_data = json.dumps({"session_id": session_id})
    return templates.TemplateResponse("login.html", {"request": request, "qr_code": generate_qr_code(qr_data), "session_id": session_id})

# ====== WebSocket 會話狀態通知 ======
@app.websocket("/ws/{session_id}")
async def websocket_endpoint(websocket: WebSocket, session_id: str):
    await websocket.accept()
    if session_id not in active_sessions:
        await websocket.close(code=1008, reason="Session 不存在")
        return
    connected_clients[session_id] = websocket
    try:
        while True:
            await websocket.receive_text()
            session = active_sessions.get(session_id)
            if not session:
                await websocket.send_json({"status": "expired"})
                break
            if session["status"] == "authenticated":
                token = create_access_token({"sub": session["user"]}, timedelta(minutes=30))
                await websocket.send_json({"status": "authenticated", "user": session["user"], "token": token})
            else:
                await websocket.send_json({"status": session["status"]})
    except WebSocketDisconnect:
        connected_clients.pop(session_id, None)

# ====== QR 登入邏輯 ======
@app.post("/api/qr-login", response_model=LoginResponse)
async def qr_login(request: SessionRequest):
    session_id = request.session_id
    session = active_sessions.get(session_id)
    if not session:
        raise HTTPException(404, "Session 不存在或已過期")

    # 已登入則強制清空
    session.update({"status": "authenticated", "user": "user1", "created_at": datetime.utcnow()})
    token = create_access_token({"sub": "user1"}, timedelta(hours=1))

    if (ws := connected_clients.get(session_id)):
        try:
            await ws.send_json({"status": "authenticated", "user": "user1", "token": token})
        except Exception as e:
            print(f"WebSocket 通知錯誤: {e}")
    return {"username": "user1", "token": token}

# ====== 登出 API ======
@app.post("/api/logout")
async def logout(request: SessionRequest):
    session_id = request.session_id
    session = active_sessions.pop(session_id, None)
    if (ws := connected_clients.pop(session_id, None)):
        try: await ws.send_json({"status": "logout", "message": "已登出"})
        except: pass
    return {"status": "success", "message": "已登出"}

# ====== 查詢會話狀態 ======
@app.get("/api/check-session/{session_id}")
async def check_session(session_id: str):
    session = active_sessions.get(session_id)
    if not session:
        raise HTTPException(404, "Session 不存在或已過期")
    return {"status": session["status"], "user": session.get("user")}

# ====== 發文與評論功能 ======
@app.get("/api/posts", response_model=List[Post])
async def get_posts(token: str = Depends(oauth2_scheme)):
    try:
        username = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM]).get("sub")
        if not username:
            raise HTTPException(401, "無效的令牌")
        return POSTS
    except jwt.PyJWTError:
        raise HTTPException(401, "無效的令牌")

@app.post("/api/posts", response_model=Post, status_code=201)
async def create_post(post: PostCreate, token: str = Depends(oauth2_scheme)):
    try:
        username = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM]).get("sub")
        if not username:
            raise HTTPException(401, "無效的令牌")
        new_post = Post(id=len(POSTS) + 1, username=username, content=post.content,
                        timestamp=datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), comments=[])
        POSTS.insert(0, new_post)
        return new_post
    except jwt.PyJWTError:
        raise HTTPException(401, "無效的令牌")

@app.post("/api/posts/{post_id}/comments", response_model=Comment, status_code=201)
async def add_comment(post_id: int, comment: CommentCreate, token: str = Depends(oauth2_scheme)):
    try:
        username = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM]).get("sub")
        if not username:
            raise HTTPException(401, "無效的令牌")
        post = next((p for p in POSTS if p.id == post_id), None)
        if not post:
            raise HTTPException(404, "貼文不存在")
        new_comment = Comment(id=len(post.comments) + 1, username=username,
                              content=comment.content, timestamp=datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"))
        post.comments.append(new_comment)
        return new_comment
    except jwt.PyJWTError:
        raise HTTPException(401, "無效的令牌")

# ====== 運行伺服器 ======
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
