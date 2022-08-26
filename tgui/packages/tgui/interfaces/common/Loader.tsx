/**
 * @file
 * @copyright 2022
 * @author jlsnow301 (https://github.com/jlsnow301)
 * @license ISC
 */
import { Box } from '../../components';
import { clamp01 } from 'common/math';

export const Loader = props => {
  const { value } = props;

  return (
    <div className="AlertModal__Loader">
      <Box
        className="AlertModal__LoaderProgress"
        style={{ width: clamp01(value) * 100 + '%' }} />
    </div>
  );
};
