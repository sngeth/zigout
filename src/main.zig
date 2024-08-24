const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
});

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;
const PADDLE_WIDTH = 100;
const PADDLE_HEIGHT = 20;
const BALL_RADIUS = 10;
const BLOCK_WIDTH = 75;
const BLOCK_HEIGHT = 20;
const BLOCKS_X = 10;
const BLOCKS_Y = 5;

const Paddle = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

const Ball = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
    radius: f32,
};

const Block = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    active: bool,
};

const GameState = struct {
    paddle: Paddle,
    ball: Ball,
    blocks: [BLOCKS_X][BLOCKS_Y]Block,

    fn init() GameState {
        var state = GameState{
            .paddle = Paddle{
                .x = SCREEN_WIDTH / 2 - PADDLE_WIDTH / 2,
                .y = SCREEN_HEIGHT - 50,
                .width = PADDLE_WIDTH,
                .height = PADDLE_HEIGHT,
            },
            .ball = Ball{
                .x = SCREEN_WIDTH / 2,
                .y = SCREEN_HEIGHT / 2,
                .dx = 5,
                .dy = -5,
                .radius = BALL_RADIUS,
            },
            .blocks = undefined,
        };

        for (0..BLOCKS_X) |i| {
            for (0..BLOCKS_Y) |j| {
                state.blocks[i][j] = Block{
                    .x = @as(f32, @floatFromInt(i)) * BLOCK_WIDTH,
                    .y = @as(f32, @floatFromInt(j)) * BLOCK_HEIGHT + 50,
                    .width = BLOCK_WIDTH,
                    .height = BLOCK_HEIGHT,
                    .active = true,
                };
            }
        }

        return state;
    }

    fn reset(self: *GameState) void {
        self.* = GameState.init();
    }
};

pub fn main() !void {
    ray.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Breakout - Zig");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    var game_state = GameState.init();

    while (!ray.WindowShouldClose()) {
        // Update
        game_state.paddle.x = @as(f32, @floatFromInt(ray.GetMouseX())) - PADDLE_WIDTH / 2;
        if (game_state.paddle.x < 0) game_state.paddle.x = 0;
        if (game_state.paddle.x > SCREEN_WIDTH - PADDLE_WIDTH) game_state.paddle.x = SCREEN_WIDTH - PADDLE_WIDTH;

        game_state.ball.x += game_state.ball.dx;
        game_state.ball.y += game_state.ball.dy;

        // Ball-wall collision
        if (game_state.ball.x - game_state.ball.radius <= 0 or game_state.ball.x + game_state.ball.radius >= SCREEN_WIDTH) game_state.ball.dx *= -1;
        if (game_state.ball.y - game_state.ball.radius <= 0) game_state.ball.dy *= -1;

        // Ball-paddle collision
        if (ray.CheckCollisionCircleRec(
            ray.Vector2{ .x = game_state.ball.x, .y = game_state.ball.y },
            game_state.ball.radius,
            ray.Rectangle{ .x = game_state.paddle.x, .y = game_state.paddle.y, .width = game_state.paddle.width, .height = game_state.paddle.height },
        )) {
            game_state.ball.dy *= -1;
        }

        // Ball-block collision
        for (0..BLOCKS_X) |i| {
            for (0..BLOCKS_Y) |j| {
                if (game_state.blocks[i][j].active and ray.CheckCollisionCircleRec(
                    ray.Vector2{ .x = game_state.ball.x, .y = game_state.ball.y },
                    game_state.ball.radius,
                    ray.Rectangle{
                        .x = game_state.blocks[i][j].x,
                        .y = game_state.blocks[i][j].y,
                        .width = game_state.blocks[i][j].width,
                        .height = game_state.blocks[i][j].height,
                    },
                )) {
                    game_state.blocks[i][j].active = false;
                    game_state.ball.dy *= -1;
                }
            }
        }

        // Check if ball is below the screen
        if (game_state.ball.y > SCREEN_HEIGHT) {
            game_state.reset();
        }

        // Check for manual restart
        if (ray.IsKeyPressed(ray.KEY_R)) {
            game_state.reset();
        }

        // Draw
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.RAYWHITE);

        ray.DrawRectangleV(
            ray.Vector2{ .x = game_state.paddle.x, .y = game_state.paddle.y },
            ray.Vector2{ .x = game_state.paddle.width, .y = game_state.paddle.height },
            ray.BLUE,
        );

        ray.DrawCircleV(ray.Vector2{ .x = game_state.ball.x, .y = game_state.ball.y }, game_state.ball.radius, ray.RED);

        for (0..BLOCKS_X) |i| {
            for (0..BLOCKS_Y) |j| {
                if (game_state.blocks[i][j].active) {
                    ray.DrawRectangleV(
                        ray.Vector2{ .x = game_state.blocks[i][j].x, .y = game_state.blocks[i][j].y },
                        ray.Vector2{ .x = game_state.blocks[i][j].width, .y = game_state.blocks[i][j].height },
                        ray.GREEN,
                    );
                }
            }
        }

        // Draw restart instructions
        ray.DrawText("Press 'R' to restart", 10, SCREEN_HEIGHT - 30, 20, ray.DARKGRAY);
    }
}
