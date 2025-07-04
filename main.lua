local menu = require("menu")
local background = require("background")

local crtShaderCode = [[
#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
    #define MY_HIGHP_OR_MEDIUMP highp
#else
    #define MY_HIGHP_OR_MEDIUMP mediump
#endif

extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP vec2 distortion_fac;
extern MY_HIGHP_OR_MEDIUMP vec2 scale_fac;
extern MY_HIGHP_OR_MEDIUMP number feather_fac;
extern MY_HIGHP_OR_MEDIUMP number noise_fac;
extern MY_HIGHP_OR_MEDIUMP number bloom_fac;
extern MY_HIGHP_OR_MEDIUMP number crt_intensity;
extern MY_HIGHP_OR_MEDIUMP number glitch_intensity;
extern MY_HIGHP_OR_MEDIUMP number scanlines;
extern MY_HIGHP_OR_MEDIUMP number glitch_bar_y;
extern MY_HIGHP_OR_MEDIUMP number glitch_bar_strength;

#define BUFF 0.01
#define BLOOM_AMT 3

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc)
{
    MY_HIGHP_OR_MEDIUMP vec2 orig_tc = tc;
    tc = tc*2.0 - vec2(1.0);
    tc *= scale_fac;
    tc += (tc.yx*tc.yx) * tc * (distortion_fac - 1.0);

    // --- HORROR GLITCH BAR ---
    MY_HIGHP_OR_MEDIUMP float glitch_dist = abs(tc.y - glitch_bar_y);
    if (glitch_dist < 0.03) {
        float amt = (0.03 - glitch_dist) / 0.03 * glitch_bar_strength;
        tc.x += sin(time * 20.0 + tc.y * 100.0) * amt * 0.04;
        tc.y += cos(time * 10.0 + tc.x * 40.0) * amt * 0.01;
    }
    // --- END HORROR GLITCH BAR ---

    MY_HIGHP_OR_MEDIUMP number mask = (1.0 - smoothstep(1.0-feather_fac,1.0,abs(tc.x) - BUFF))
                * (1.0 - smoothstep(1.0-feather_fac,1.0,abs(tc.y) - BUFF));
    tc = (tc + vec2(1.0))/2.0;
    MY_HIGHP_OR_MEDIUMP number offset_l = 0.;
    MY_HIGHP_OR_MEDIUMP number offset_r = 0.;
    if(glitch_intensity > 0.01){
        MY_HIGHP_OR_MEDIUMP number timefac = 3.0*time;
        offset_l = 50.0*(-3.5+sin(timefac*0.512 + tc.y*40.0)
                + sin(-timefac*0.8233 + tc.y*81.532)
                + sin(timefac*0.333 + tc.y*30.3)
                + sin(-timefac*0.1112331 + tc.y*13.0));
        offset_r = -50.0*(-3.5+sin(timefac*0.6924 + tc.y*29.0)
                + sin(-timefac*0.9661 + tc.y*41.532)
                + sin(timefac*0.4423 + tc.y*40.3)
                + sin(-timefac*0.13321312 + tc.y*11.0));
        if(glitch_intensity > 1.0){
            offset_l = 50.0*(-1.5+sin(timefac*0.512 + tc.y*4.0)
                + sin(-timefac*0.8233 + tc.y*1.532)
                + sin(timefac*0.333 + tc.y*3.3)
                + sin(-timefac*0.1112331 + tc.y*1.0));
            offset_r = -50.0*(-1.5+sin(timefac*0.6924 + tc.y*19.0)
                + sin(-timefac*0.9661 + tc.y*21.532)
                + sin(timefac*0.4423 + tc.y*20.3)
                + sin(-timefac*0.13321312 + tc.y*5.0));
        }  
        tc.x = tc.x + 0.001*glitch_intensity*clamp(offset_l, clamp(offset_r, -1.0, 0.0), 1.0);
    }
    MY_HIGHP_OR_MEDIUMP vec4 crt_tex = Texel( tex, tc);
    MY_HIGHP_OR_MEDIUMP float artifact_amplifier = (abs(clamp(offset_l, clamp(offset_r, -1.0, 0.0), 1.0))*glitch_intensity > 0.9 ? 3. : 1.);
    MY_HIGHP_OR_MEDIUMP float crt_amout_adjusted = (max(0., (crt_intensity)/(0.16*0.3)))*artifact_amplifier;
    if(crt_amout_adjusted > 0.0000001) {
        crt_tex.r = crt_tex.r*(1.-crt_amout_adjusted) + crt_amout_adjusted*Texel( tex, tc + vec2(0.0005*(1. +10.*(artifact_amplifier - 1.))*1600./love_ScreenSize.x, 0.)).r;
        crt_tex.g = crt_tex.g*(1.-crt_amout_adjusted) + crt_amout_adjusted*Texel( tex, tc + vec2(-0.0005*(1. +10.*(artifact_amplifier - 1.))*1600./love_ScreenSize.x, 0.)).g;
    }
    MY_HIGHP_OR_MEDIUMP vec3 rgb_result = crt_tex.rgb*(1.0 - (1.0*crt_intensity*artifact_amplifier));
    if (sin(time + tc.y*200.0) > 0.85) {
        if (offset_l < 0.99 && offset_l > 0.01) rgb_result.r = rgb_result.g*1.5;
        if (offset_r > -0.99 && offset_r < -0.01) rgb_result.g = rgb_result.r*1.5;
    }
    MY_HIGHP_OR_MEDIUMP vec3 rgb_scanline = 1.0*vec3( 
        clamp(-0.3+2.0*sin( tc.y * scanlines-3.14/4.0) - 0.8*clamp(sin( tc.x*scanlines*4.0), 0.4, 1.0), -1.0, 2.0),
        clamp(-0.3+2.0*cos( tc.y * scanlines) - 0.8*clamp(cos( tc.x*scanlines*4.0), 0.0, 1.0), -1.0, 2.0),
        clamp(-0.3+2.0*cos( tc.y * scanlines -3.14/3.0) - 0.8*clamp(cos( tc.x*scanlines*4.0-3.14/4.0), 0.0, 1.0), -1.0, 2.0));
    rgb_result += crt_tex.rgb * rgb_scanline * crt_intensity * artifact_amplifier;
    MY_HIGHP_OR_MEDIUMP number x = (tc.x - mod(tc.x, 0.002)) * (tc.y - mod(tc.y, 0.0013)) * time * 1000.0;
    x = mod( x, 13.0 ) * mod( x, 123.0 );
    MY_HIGHP_OR_MEDIUMP number dx = mod( x, 0.11 )/0.11;
    rgb_result = (1.0-clamp( noise_fac*artifact_amplifier, 0.0,1.0 ))*rgb_result + dx * clamp( noise_fac*artifact_amplifier, 0.0,1.0 ) * vec3(1.0,1.0,1.0);
    rgb_result -= vec3(0.55 - 0.02*(artifact_amplifier - 1. - crt_amout_adjusted*bloom_fac*0.7));
    rgb_result = rgb_result*(1.0 + 0.14 + crt_amout_adjusted*(0.012 - bloom_fac*0.12));
    rgb_result += vec3(0.5);
    MY_HIGHP_OR_MEDIUMP vec4 final_col = vec4( rgb_result*1.0, 1.0 );
    MY_HIGHP_OR_MEDIUMP vec4 col = vec4(0.0);
    MY_HIGHP_OR_MEDIUMP float bloom = 0.0;
    if (bloom_fac > 0.00001 && crt_intensity > 0.000001){
        bloom = 0.03*(max(0., (crt_intensity)/(0.16*0.3)));
        MY_HIGHP_OR_MEDIUMP float bloom_dist = 0.0015*float(BLOOM_AMT);
        MY_HIGHP_OR_MEDIUMP vec4 samp;
        MY_HIGHP_OR_MEDIUMP float cutoff = 0.6;
        for (int i = -BLOOM_AMT; i <= BLOOM_AMT; ++i)
            for (int j = -BLOOM_AMT; j <= BLOOM_AMT; ++j){
                samp = Texel( tex, tc + (bloom_dist/float(BLOOM_AMT))*vec2(float(i), float(j)));
                samp.r = max(1./(1.-cutoff)*samp.r - 1./(1.-cutoff) + 1., 0.);
                samp.g = max(1./(1.-cutoff)*samp.g - 1./(1.-cutoff) + 1., 0.);
                samp.b = max(1./(1.-cutoff)*samp.b - 1./(1.-cutoff) + 1., 0.);
                col += min(min(samp.r,samp.g),samp.b) * (2. - float(abs(float(i+j)))/float(BLOOM_AMT+BLOOM_AMT));
        }   
        col /= float(BLOOM_AMT*BLOOM_AMT);
        col.a = final_col.a;
    }
    return (final_col*(1. -1.*bloom) + bloom*col)*mask;
}
#ifdef VERTEX
extern MY_HIGHP_OR_MEDIUMP vec2 mouse_screen_pos;
extern MY_HIGHP_OR_MEDIUMP float hovering;
extern MY_HIGHP_OR_MEDIUMP float screen_scale;
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    if (hovering <= 0.){
        return transform_projection * vertex_position;
    }
    MY_HIGHP_OR_MEDIUMP float mid_dist = screen_scale*length(vertex_position.xy/screen_scale - 0.5*love_ScreenSize.xy)/length(love_ScreenSize.xy);
    MY_HIGHP_OR_MEDIUMP vec2 mouse_offset = (vertex_position.xy - mouse_screen_pos.xy)/screen_scale;
    MY_HIGHP_OR_MEDIUMP float scale = 0.002*(-0.03 - 0.3*max(0., 0.3-mid_dist))
                *hovering*(length(mouse_offset)*length(mouse_offset))/(2. -mid_dist);
    return transform_projection * vertex_position + vec4(0,0,0,scale);
}
#endif
]]

local crtShader
local menuCanvas

function love.load()
    love.window.setFullscreen(true)
    background.load()
    menu.load()
    crtShader = love.graphics.newShader(crtShaderCode)
    menuCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.resize(w, h)
    menuCanvas = love.graphics.newCanvas(w, h)
end

function love.update(dt)
    background.update(dt)
    menu.update(dt)
end

function love.draw()
    love.graphics.setCanvas(menuCanvas)
    love.graphics.clear()
    background.draw()
    menu.draw()
    love.graphics.setCanvas()

    -- Dynamic CRT parameters
    local crt = menu.getCRTIntensity()
    local distortion = 1.0 + 0.10 * crt
    local feather = 0.01 + 0.18 * crt
    local noise = 0.0 + 0.10 * crt
    local bloom = 0.0 + 0.18 * crt
    local crt_intensity = 0.0 + 0.28 * crt
    local scanlines = 0.0 + 1200.0 * crt

    -- Glitch bar
    local bar_speed = 0.25 + 0.75 * crt
    local bar_y = (love.timer.getTime() * bar_speed) % 1.0
    crtShader:send("glitch_bar_y", bar_y)
    crtShader:send("glitch_bar_strength", crt)

    love.graphics.setShader(crtShader)
    crtShader:send("time", love.timer.getTime())
    crtShader:send("distortion_fac", {distortion, distortion})
    crtShader:send("scale_fac", {1.0, 1.0})
    crtShader:send("feather_fac", feather)
    crtShader:send("noise_fac", noise)
    crtShader:send("bloom_fac", bloom)
    crtShader:send("crt_intensity", crt_intensity)
    crtShader:send("glitch_intensity", 0.0)
    crtShader:send("scanlines", scanlines)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(menuCanvas, 0, 0)
    love.graphics.setShader()
end

function love.mousepressed(x, y, button)
    menu.mousepressed(x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
    if menu.mousemoved then
        menu.mousemoved(x, y, dx, dy, istouch)
    end
end

function love.mousereleased(x, y, buttonNum)
    if menu.mousereleased then
        menu.mousereleased(x, y, buttonNum)
    end
end