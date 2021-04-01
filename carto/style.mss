@traversed-color: #264653;
@untraversed-color: #e76f51;

#traversed-paths {
    background/line-color: @traversed-color;
    background/line-width: 2;
    [zoom >= 16] {
        background/line-width: 4;
        line-color: #fff;
        line-width: 2;
        line-dasharray: 2,2;
    }
}

#untraversed-paths {
    line-color: @untraversed-color;
    line-width: 2;
    [zoom >= 16] {
        line-width: 4;
    }
}
