@traversed-color: #264653;
@untraversed-color: #e76f51;

#traversed-paths {
    [zoom >= 5] {
        background/line-color: @traversed-color;
        background/line-width: 1;
        line-color: #55F;
        line-width: 0.4;
        line-dasharray: 4,4;
        [zoom >= 16] {
            background/line-width: 2;
            line-width: 0.8;
            line-dasharray: 6,6;
        }
    }
}

#untraversed-paths {
    [zoom >= 5] {
        background/line-color: @untraversed-color;
        background/line-width: 1;
        line-color: #F55;
        line-width: 0.4;
        line-dasharray: 4,4;
        [zoom >= 16] {
            background/line-width: 2;
            line-width: 0.8;
            line-dasharray: 6,6;
        }
    }
}
